import InputText from "../../../components/layout/fields/inputText";

export default function FieldLastname(props) {
  const { handler, value } = props;

  return (
    <>
      <InputText
        handler={handler}
        value={value}
        form="profilegroups"
        label="Name"
        fieldName="name"
        placeholder="Ingresa nombre del grupo"
      />
    </>
  );
}
