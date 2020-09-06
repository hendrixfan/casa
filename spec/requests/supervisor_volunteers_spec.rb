require "rails_helper"

RSpec.describe "/supervisor_volunteers", type: :request do
  let!(:admin) { create(:casa_admin) }
  let!(:supervisor) { create(:supervisor) }
  let!(:volunteer) { create(:volunteer) }

  context "POST /create" do
    context "when no pre-existing association between supervisr and volunteer exists" do
      it "creates a new supervisor_volunteers association" do
        valid_parameters = {
          supervisor_volunteer: {volunteer_id: volunteer.id},
          supervisor_id: supervisor.id
        }
        sign_in(admin)

        expect {
          post supervisor_volunteers_url, params: valid_parameters
        }.to change(SupervisorVolunteer, :count).by(1)
      end
    end

    context "when an inactive association between supervisor and volunteer exists" do
      let!(:association) do
        create(
          :supervisor_volunteer,
          supervisor: supervisor,
          volunteer: volunteer,
          is_active: false
        )
      end
      it "sets that association to active" do
        valid_parameters = {
          supervisor_volunteer: {volunteer_id: volunteer.id},
          supervisor_id: supervisor.id
        }
        sign_in(admin)

        expect {
          post supervisor_volunteers_url, params: valid_parameters
        }.not_to change(SupervisorVolunteer, :count)

        association.reload
        expect(association.is_active?).to be(true)
      end
    end

    context "when an inactive association between the volunteer and a different supervisor exists" do
      let!(:other_supervisor) { create(:supervisor) }
      let!(:previous_association) do
        create(
          :supervisor_volunteer,
          supervisor: other_supervisor,
          volunteer: volunteer,
          is_active: false
        )
      end

      it "replaces that association" do
        valid_parameters = {
          supervisor_volunteer: {volunteer_id: volunteer.id},
          supervisor_id: supervisor.id
        }
        sign_in(admin)

        expect {
          post supervisor_volunteers_url, params: valid_parameters
        }.not_to change(SupervisorVolunteer, :count)

        expect(SupervisorVolunteer.exists?(previous_association.id)).to be(false)
        expect(SupervisorVolunteer.where(supervisor: supervisor, volunteer: volunteer).exists?).to be(true)
      end
    end
  end

  context "PATCH /unassign" do
    let!(:association) do
      create(:supervisor_volunteer, supervisor: supervisor, volunteer: volunteer)
    end

    context "when the logged in user is an admin" do
      it "sets the is_active flag for assignment of a volunteer to a supervisor to false" do
        sign_in admin

        expect {
          patch unassign_supervisor_volunteer_path(volunteer)
        }.not_to change(supervisor.volunteers, :count)

        association.reload
        expect(association.is_active?).to be(false)
        expect(response).to redirect_to edit_supervisor_path(supervisor)
      end
    end

    context "when the logged in user is a supervisor" do
      it "sets the is_active flag for assignment of a volunteer to a supervisor to false" do
        sign_in supervisor

        expect {
          patch unassign_supervisor_volunteer_path(volunteer)
        }.not_to change(supervisor.volunteers, :count)

        association.reload

        expect(association.is_active?).to be(false)
        expect(response).to redirect_to edit_supervisor_path(supervisor)
      end
    end

    context "when the logged in user is not an admin or supervisor" do
      let!(:association) do
        create(:supervisor_volunteer, supervisor: supervisor, volunteer: volunteer)
      end
      it "does not set the is_active flag on the association to false" do
        sign_in volunteer

        expect {
          patch unassign_supervisor_volunteer_path(volunteer)
        }.not_to change(supervisor.volunteers, :count)

        association.reload

        expect(association.is_active?).to be(true)
      end
    end
  end
end
